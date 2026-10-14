@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalReadExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalReadExceptionStore = Imaging.newMemorySeasonalReadExceptionStore()
        let item = Imaging.newSeasonalReadException("code-328", label: "label-435")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
