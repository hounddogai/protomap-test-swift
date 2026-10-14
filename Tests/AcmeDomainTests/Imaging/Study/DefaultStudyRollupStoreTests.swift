@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryDefaultStudyRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.DefaultStudyRollupStore = Imaging.newMemoryDefaultStudyRollupStore()
        let item = Imaging.newDefaultStudyRollup("code-364", label: "label-804")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
