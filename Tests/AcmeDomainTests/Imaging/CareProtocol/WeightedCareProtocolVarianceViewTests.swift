@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedCareProtocolVariance("code-811", title: "title-269")
        let view = Imaging.toWeightedCareProtocolVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedCareProtocolVarianceViews([item, item]).count == 2)
    }
}
