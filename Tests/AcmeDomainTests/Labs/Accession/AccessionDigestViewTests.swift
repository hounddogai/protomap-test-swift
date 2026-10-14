@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionDigest("code-631", title: "title-523")
        let view = Labs.toAccessionDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionDigestViews([item, item]).count == 2)
    }
}
