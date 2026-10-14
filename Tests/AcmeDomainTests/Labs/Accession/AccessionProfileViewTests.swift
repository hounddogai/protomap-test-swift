@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionProfile("code-516", label: "label-329")
        let view = Labs.toAccessionProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionProfileViews([item, item]).count == 2)
    }
}
