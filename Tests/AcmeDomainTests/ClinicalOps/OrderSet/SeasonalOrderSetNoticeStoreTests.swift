@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalOrderSetNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalOrderSetNoticeStore = ClinicalOps.newMemorySeasonalOrderSetNoticeStore()
        let item = ClinicalOps.newSeasonalOrderSetNotice("code-891", label: "label-44")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
