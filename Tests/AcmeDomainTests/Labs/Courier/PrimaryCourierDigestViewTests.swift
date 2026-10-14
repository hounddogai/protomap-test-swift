@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryCourierDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPrimaryCourierDigest("code-177", title: "title-297")
        let view = Labs.toPrimaryCourierDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPrimaryCourierDigestViews([item, item]).count == 2)
    }
}
