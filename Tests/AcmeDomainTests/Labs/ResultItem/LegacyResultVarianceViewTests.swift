@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyResultVariance("code-302", title: "title-740")
        let view = Labs.toLegacyResultVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyResultVarianceViews([item, item]).count == 2)
    }
}
