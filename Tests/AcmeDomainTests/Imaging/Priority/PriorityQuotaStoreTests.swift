@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityQuotaStore = Imaging.newMemoryPriorityQuotaStore()
        let item = Imaging.newPriorityQuota("code-973", label: "label-100")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
