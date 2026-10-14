@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRollingModalityAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RollingModalityAuditStore = Imaging.newMemoryRollingModalityAuditStore()
        let item = Imaging.newRollingModalityAudit("code-218", title: "title-495")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
