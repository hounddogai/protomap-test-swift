@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryDefaultCareProtocolAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.DefaultCareProtocolAuditStore = Imaging.newMemoryDefaultCareProtocolAuditStore()
        let item = Imaging.newDefaultCareProtocolAudit("code-821", title: "title-470")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
