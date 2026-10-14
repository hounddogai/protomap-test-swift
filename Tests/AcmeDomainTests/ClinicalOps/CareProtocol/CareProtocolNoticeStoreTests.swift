@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolNoticeStore = ClinicalOps.newMemoryCareProtocolNoticeStore()
        let item = ClinicalOps.newCareProtocolNotice("code-67", title: "title-817")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
