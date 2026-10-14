@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedSpecimenMetric("code-176", label: "label-349")
        let view = Labs.toBatchedSpecimenMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedSpecimenMetricViews([item, item]).count == 2)
    }
}
