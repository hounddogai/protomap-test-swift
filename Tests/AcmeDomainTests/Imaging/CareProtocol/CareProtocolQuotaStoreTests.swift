@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolQuotaStore = Imaging.newMemoryCareProtocolQuotaStore()
        let item = Imaging.newCareProtocolQuota("code-556", label: "label-635")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
