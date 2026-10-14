@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalReadException("code-328", label: "label-435")
        let view = Imaging.toSeasonalReadExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalReadExceptionViews([item, item]).count == 2)
    }
}
