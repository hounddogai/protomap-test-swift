@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingModalityQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingModalityQuotaStore = Imaging.newMemoryPendingModalityQuotaStore()
        let item = Imaging.newPendingModalityQuota("code-163", label: "label-515")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
