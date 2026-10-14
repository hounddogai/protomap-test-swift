@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolMetric("code-656", name: "name-223")
        let view = Imaging.toCareProtocolMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolMetricViews([item, item]).count == 2)
    }
}
