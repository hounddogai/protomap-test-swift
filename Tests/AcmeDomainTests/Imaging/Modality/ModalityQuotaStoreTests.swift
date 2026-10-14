@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityQuotaStore = Imaging.newMemoryModalityQuotaStore()
        let item = Imaging.newModalityQuota("code-277", title: "title-160")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
