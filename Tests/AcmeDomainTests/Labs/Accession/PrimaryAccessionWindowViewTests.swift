@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPrimaryAccessionWindow("code-483", label: "label-661")
        let view = Labs.toPrimaryAccessionWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPrimaryAccessionWindowViews([item, item]).count == 2)
    }
}
