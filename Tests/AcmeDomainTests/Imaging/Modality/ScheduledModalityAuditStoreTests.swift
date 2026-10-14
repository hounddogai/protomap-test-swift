@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledModalityAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledModalityAuditStore = Imaging.newMemoryScheduledModalityAuditStore()
        let item = Imaging.newScheduledModalityAudit("code-208", title: "title-714")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
