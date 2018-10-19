//
//  LoginViewController.swift
//  BiocheckMovil
//
//  Created by Arturo Avalos on 4/16/18.
//  Copyright © 2018 Arturo Avalos. All rights reserved.
//

import UIKit
import os.log
import AutoKeyboard

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var editCol = UIColor(red:0.00, green:1.00, blue:0.80, alpha:1.0)
    
    @IBOutlet weak var txtFldSubDom: UITextField!
    @IBOutlet weak var txtFldIdEmp: UITextField!
    @IBOutlet weak var txtFldNip: UITextField!
    @IBOutlet weak var lblSubDom: UILabel!
    @IBOutlet weak var lblIdEmp: UILabel!
    @IBOutlet weak var lblNip: UILabel!
    @IBOutlet weak var btnLogin: UIButton!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setTxtFld(txtFld: txtFldSubDom, col: UIColor.white)
        setTxtFld(txtFld: txtFldIdEmp, col: UIColor.white)
        setTxtFld(txtFld: txtFldNip, col: UIColor.white)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setTxtFld(txtFld: UITextField, col: UIColor){
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = col.cgColor
        border.frame = CGRect(x: 0, y: txtFld.frame.size.height - width, width:  txtFld.frame.size.width, height: txtFld.frame.size.height)

        border.borderWidth = width
        txtFld.layer.addSublayer(border)
        txtFld.layer.masksToBounds = true
        txtFld.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag + 1 == txtFldIdEmp.tag {
            txtFldIdEmp.becomeFirstResponder()
        }
        
        else if textField.tag + 1 == txtFldNip.tag {
            txtFldIdEmp.endEditing(true)
            txtFldNip.becomeFirstResponder()
        }
        
        else {
            self.view.endEditing(true)
        }
        
        print(textField.tag)
        return true        
    }
    
    @IBAction func onTxtFldSubDomEditBegin(_ sender: UITextField) {
        setTxtFld(txtFld: sender, col: editCol)
        lblSubDom.textColor = editCol
    }
    @IBAction func onTxtFldSubDomEditEnd(_ sender: UITextField) {
        setTxtFld(txtFld: sender, col: UIColor.white)
        lblSubDom.textColor = UIColor.white
    }
    
    @IBAction func onTxtFldIdEmpBeingEdit(_ sender: UITextField) {
        setTxtFld(txtFld: sender, col: editCol)
        lblIdEmp.textColor = editCol
    }
    @IBAction func onTxtFldIdEmpEditEnd(_ sender: UITextField) {
        setTxtFld(txtFld: sender, col: UIColor.white)
        lblIdEmp.textColor = UIColor.white
    }

    @IBAction func onTxtFldNipBeginEdit(_ sender: UITextField) {
        setTxtFld(txtFld: sender, col: editCol)
        lblNip.textColor = editCol
        registerAutoKeyboard()
        txtFldIdEmp.isEnabled = false
        txtFldSubDom.isEnabled = false

    }
    @IBAction func onTxtFldNipBeginEnd(_ sender: UITextField) {
        setTxtFld(txtFld: sender, col: UIColor.white)
        lblNip.textColor = UIColor.white
        unRegisterAutoKeyboard()
        txtFldIdEmp.isEnabled = true
        txtFldSubDom.isEnabled = true
    }
    
    @IBAction func onBtnInTouchUpInside(_ sender: UIButton) {
        let alert = UIAlertController(title: "Error", message: "Error no especificado",preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
        guard !(txtFldSubDom.text?.isEmpty)! && !(txtFldIdEmp.text?.isEmpty)! && !(txtFldNip.text?.isEmpty)! else {
            alert.message = "No debe haber campos vacios"
            self.present(alert, animated: true, completion: nil)
            return
        }

        let params: [String: Any] = ["checkId": txtFldIdEmp.text?.trimmingCharacters(in: NSCharacterSet.whitespaces), "nip": txtFldNip.text!.trimmingCharacters(in: NSCharacterSet.whitespaces), "subdomain": txtFldSubDom.text!.trimmingCharacters(in: NSCharacterSet.whitespaces)]

        guard let url = URL(string:"https://api-m.biocheck.net/login") else { return }
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else { return }
        request.httpBody = httpBody

        let sesion = URLSession.shared.dataTask(with: request) { (responseData: Data?, response: URLResponse?, error: Error?) in
            DispatchQueue.main.async { self.btnLogin.isEnabled = true }
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let data = responseData {
                        let tokenStr = String(data: data, encoding: String.Encoding.utf8) as String?
                        let logSession = Login(token: tokenStr)
                        NSKeyedArchiver.archiveRootObject(logSession!, toFile: Login.ArchiveURL.path)

                        if Check.getCheck() != nil {
                            let checkLog = Check(checks: 0, imgChecks: 0)
                            NSKeyedArchiver.archiveRootObject(checkLog!, toFile: Check.ArchiveURL.path)
                        }

                        DispatchQueue.main.async {
                            let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
                            appDelegate?.logIn()
                        }
                        return
                    }

                } else {
                    if let data = responseData {
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        if let dictionary = json as? [String: Any] {
                            if let message = dictionary["message"] as? String {
                                switch message {
                                    case "INVALID_SUBDOMAIN":
                                        alert.message = "No existe la compañia"
                                        break
                                    case "INVALID_NIP":
                                        alert.message = "Nip incorrecto"
                                        break
                                    case "INVALID_USER":
                                        alert.message = "Id de Empleado no encontrado o no está habilitado"
                                        break
                                    default:
                                        break
                                }
                            }
                            else if let status = dictionary["status"] as? String {
                                if status == "INTERNAL_SERVER_ERROR" {
                                    alert.message = "El empleado no esta habilitado"
                                }
                            }
                        }
                        
                    }
                }
            } else {
                let error = (error! as NSError).code
                
                switch error {
                case -1001:
                    alert.message = "Sin respuesta del servidor"
                    break
                case -1009:
                    alert.message = "Error de red, revisa tu conexión a internet"
                    break
                default: break
                    
                }
            }
            
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
        btnLogin.isEnabled = false
        sesion.resume()
    }
}
