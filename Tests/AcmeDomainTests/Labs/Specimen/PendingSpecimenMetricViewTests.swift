@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingSpecimenMetric("code-771", label: "label-856")
        let view = Labs.toPendingSpecimenMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingSpecimenMetricViews([item, item]).count == 2)
    }
}
