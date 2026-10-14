@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedReadBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedReadBaselineStore = Imaging.newMemoryCappedReadBaselineStore()
        let item = Imaging.newCappedReadBaseline("code-909", name: "name-224")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
