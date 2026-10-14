@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolAuditStore = Imaging.newMemoryCareProtocolAuditStore()
        let item = Imaging.newCareProtocolAudit("code-682", title: "title-645")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
