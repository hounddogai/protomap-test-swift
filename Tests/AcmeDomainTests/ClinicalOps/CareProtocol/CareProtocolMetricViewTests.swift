@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCareProtocolMetric("code-542", name: "name-831")
        let view = ClinicalOps.toCareProtocolMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCareProtocolMetricViews([item, item]).count == 2)
    }
}
