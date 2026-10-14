@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackCareProtocolAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackCareProtocolAuditStore = Imaging.newMemoryFallbackCareProtocolAuditStore()
        let item = Imaging.newFallbackCareProtocolAudit("code-109", title: "title-931")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
