//
//  ViewController.swift
//  TestMapApp
//
//  Created by Tsenguun Batbold on 25/9/20.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var PassworldTextField: UITextField!
    @IBOutlet weak var useCredentialsSwitch: UISwitch!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let username = "admin"
    let password = "123456"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        PassworldTextField.isSecureTextEntry = true
        //self.hideKeyboardWhenTappedAround()
    
    }
    

    @IBAction func loginBtn(_ sender: Any) {
        if !useCredentialsSwitch.isOn {
            performSegue(withIdentifier: "login", sender: self)
            return
        }
        
        if EmailTextField.text == username &&
            PassworldTextField.text == password {
            print("Logged in")
            performSegue(withIdentifier: "login", sender: self)
            
        } else {
            print("Email or Password is wrong")
            let alert = UIAlertController(title: "Login", message: "Username or Password is wrong", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            
            self.present(alert, animated: true)


        }
    }
    
}

//extension UIViewController:  {
//    func hideKeyboardWhenTappedAround() {
//        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
//        tap.cancelsTouchesInView = false
//        view.addGestureRecognizer(tap)
//    }
//
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
extension ViewController: UITextFieldDelegate {

    @objc func keyboardWillShow(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo else {return}
        guard var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {return}
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension UIView {
    func blink() {
        self.alpha = 0.0;
        UIView.animate(withDuration: 0.5, //Time duration you want,
            delay: 0.0,
            options: [.curveEaseInOut, .autoreverse, .repeat],
            animations: { [weak self] in self?.alpha = 1.0 },
            completion: { [weak self] _ in self?.alpha = 0.0 })
    }

    func stopBlink() {
        layer.removeAllAnimations()
        alpha = 1
    }
}




