@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyCheckpoint("code-16", title: "title-215")
        let view = Consent.toProxyCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyCheckpointViews([item, item]).count == 2)
    }
}
