@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadAuditStore = Imaging.newMemoryReadAuditStore()
        let item = Imaging.newReadAudit("code-417", label: "label-38")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
