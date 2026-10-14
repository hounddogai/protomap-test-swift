@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacySpecimenMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacySpecimenMetric("code-329", name: "name-358")
        let view = Labs.toLegacySpecimenMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacySpecimenMetricViews([item, item]).count == 2)
    }
}
