//
//  ViewController.swift
//  MOPP POC
//
//  Created by Katrin Annuk on 12/12/16.
//  Copyright © 2016 Katrin Annuk. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate, ABTBluetoothReaderManagerDelegate, ABTBluetoothReaderDelegate {
    @IBOutlet weak var cardReaderCell: UITableViewCell!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idCodeLabel: UILabel!
    @IBOutlet weak var birthDateLabel: UILabel!
    
    var centralManager:CBCentralManager!
    var peripheral:CBPeripheral! {
        didSet {
            if peripheral != nil {
                if peripheral.name != nil && peripheral.name!.characters.count > 0 {
                    cardReaderCell.textLabel?.text = peripheral.name
                } else {
                    cardReaderCell.textLabel?.text = peripheral.identifier.uuidString
                }
            } else {
                cardReaderCell.textLabel?.text = "Ühenda lugejaga"
            }
        }
    }
    var peripherals:NSMutableArray = []
    
    var commands:Array<Data> = Array()
    
    var readerSelection:ReaderSelectionController?
    var bluetoothReader:ABTBluetoothReader?
    var bluetoothReaderManager:ABTBluetoothReaderManager?
    
    let commandSelectMaster = "00 A4 00 0C"
    let commandSelectEEEE = "00 A4 01 0C 02 EEEE"
    let commandSelect5044 = "00 A4 02 04 02 50 44"
    let commandReadLastName = "00 B2 01 04"
    let commandReadFirstNameLine1 = "00 B2 02 04"
    let commandReadFirstNameLine2 = "00 B2 03 04"

    var firstNameLine1:String = ""
    var firstNameLine2:String = ""
    var lastName:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        bluetoothReaderManager = ABTBluetoothReaderManager()
        bluetoothReaderManager?.delegate = self
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "ReaderSelection" {
            
            readerSelection = segue.destination as? ReaderSelectionController
            readerSelection?.peripheral = nil
            readerSelection?.peripherals = peripherals
            
            if peripheral != nil {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            
            
            if centralManager.state == CBManagerState.poweredOn {
                print("Starting scan")

                centralManager.scanForPeripherals(withServices: nil, options: nil)
            } else {
                print("Bluetooth not available")
            }
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        
        if segue.source is ReaderSelectionController {
            print("Stoping scan")

            centralManager.stopScan()
            peripheral = readerSelection?.peripheral
            
            print("Selected peripheral \(peripheral)")
            
            centralManager.connect(peripheral, options: nil)
            
        }
    }
    
    // MARK: - CBCentralManager
    
    private var firstRun = true;
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central manager did update state \(central.state)")

        var message:NSString?
        
        switch central.state {
        case CBManagerState.unknown,
             CBManagerState.resetting:
            message = "The update is being started. Please wait until Bluetooth is ready."
            break
            
        case CBManagerState.unsupported:
            message = "This device does not support Bluetooth low energy."
            break
            
        case CBManagerState.unauthorized:
            message = "This app is not authorized to use Bluetooth low energy."
            break
            
        case CBManagerState.poweredOff:
            if firstRun == false {
                message = "You must turn on Bluetooth in Settings in order to use the reader."
            }
            break
        default:
            break
        }
        
        if message != nil {
            let alertController = UIAlertController(title: "Bluetooth", message: "\(message)", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
                print("Foo")}))
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Central manager did connect")

        bluetoothReaderManager?.detectReader(with: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Central manager did discover \(peripheral.name)")

        if peripherals.index(of: peripheral) == NSNotFound {

            peripherals.add(peripheral)
            if readerSelection != nil {
                readerSelection!.peripherals = peripherals
            }
        }
    }
    
    // MARK: - Bluetooth reader manager
    
    func bluetoothReaderManager(_ bluetoothReaderManager: ABTBluetoothReaderManager!, didDetect reader: ABTBluetoothReader!, peripheral: CBPeripheral!, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
            bluetoothReader = reader
            bluetoothReader?.delegate = self
            bluetoothReader?.attach(peripheral)
        }
    }

    // MARK: - Bluetooth Reader
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didAttach peripheral: CBPeripheral!, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
            let alertController = UIAlertController(title: "Reader attached", message: "The reader is attached to the peripheral successfully.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
                self.readCardPublicData()}))
            self.present(alertController, animated: true, completion: nil)
            
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnDeviceInfo deviceInfo: NSObject!, type: UInt, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didAuthenticateWithError error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
            bluetoothReader?.powerOnCard()
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnAtr atr: Data!, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
            self.transmitNextCommand()
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didPowerOffCardWithError error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
        }
    }
    
    
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnCardStatus cardStatus: UInt, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
            
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnResponseApdu apdu: Data!, error: Error!) {
        let commandData = commands.first
        let commandString = ABDHex.hexString(fromByteArray: commandData)
        commands.removeFirst()
        
        if error != nil {
            self.showError(error: error)
            self.transmitNextCommand()
            
        } else {
            
            print("return apdu \(ABDHex.hexString(fromByteArray: apdu))")
            
            let trimmedApdu = self.removeOkTrailer(string: ABDHex.hexString(fromByteArray: apdu))

            if commandString == commandReadLastName {
                lastName = self.hexToString(string: trimmedApdu)
                self.updateName()
            }
            
            if commandString == commandReadFirstNameLine1 {
                firstNameLine1 = self.hexToString(string: trimmedApdu)
                self.updateName()
            }
            
            if commandString == commandReadFirstNameLine2 {
                firstNameLine2 = self.hexToString(string: trimmedApdu)
                self.updateName()
            }
            
            self.transmitNextCommand()
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnEscapeResponse response: Data!, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didChangeCardStatus cardStatus: UInt, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didChangeBatteryStatus batteryStatus: UInt, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didChangeBatteryLevel batteryLevel: UInt, error: Error!) {
        if error != nil {
            self.showError(error: error)
            
        } else {
        }
    }
    
    // MARK: - Private methods
    func showError(error: Error!) {
        let alertController = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
            print("Foo")}))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func readCardPublicData() {
        
        commands.append(ABDHex.byteArray(fromHexString: commandSelectMaster))
        commands.append(ABDHex.byteArray(fromHexString: commandSelectEEEE))
        commands.append(ABDHex.byteArray(fromHexString: commandSelect5044))
        commands.append(ABDHex.byteArray(fromHexString: commandReadLastName))
        commands.append(ABDHex.byteArray(fromHexString: commandReadFirstNameLine1))
        commands.append(ABDHex.byteArray(fromHexString: commandReadFirstNameLine2))
        
        bluetoothReader?.authenticate(withMasterKey:ABDHex.byteArray(fromHexString: "FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF"))

    }
    
    func transmitNextCommand() {
        if commands.count > 0 {
            let data = commands.first
            bluetoothReader?.transmitApdu(data)
        }
    }
    
    func hexToString(string:String) -> String {
        let components = string.components(separatedBy: " ")
        let charArray = components.map { char -> Character in
            let code = Int(strtoul(char, nil, 16))
            return Character(UnicodeScalar(code)!)
        }

        var result = String(charArray)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }
    
    func removeOkTrailer(string:String) -> String {
        var newString = string
        if newString.hasSuffix("90 00") {
            let toIndex = newString.index(newString.endIndex, offsetBy: -5)
            
            newString = newString.substring(to: toIndex)
        }
        
        newString = newString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return newString
    }
    
    func updateName() {
        var name = ""
        var separator = ""
        
        if firstNameLine1.characters.count > 0 {
            name.append(firstNameLine1)
            separator = " "
        }
        
        if firstNameLine2.characters.count > 0 {
            name.append(separator)
            name.append(firstNameLine2)
            separator = " "
        }
        
        if lastName.characters.count > 0 {
            name.append(separator)
            name.append(lastName)
            separator = " "
        }
        
        print("name: \(name)")
        if name.characters.count > 0 {
            self.nameLabel.text = name
        } else {
            self.nameLabel.text = "-"
        }
    }
}

