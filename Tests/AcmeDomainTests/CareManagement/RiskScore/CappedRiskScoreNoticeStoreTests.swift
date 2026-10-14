@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedRiskScoreNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedRiskScoreNoticeStore = CareManagement.newMemoryCappedRiskScoreNoticeStore()
        let item = CareManagement.newCappedRiskScoreNotice("code-77", label: "label-952")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
