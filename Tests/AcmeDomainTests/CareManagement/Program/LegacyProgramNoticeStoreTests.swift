@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyProgramNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyProgramNoticeStore = CareManagement.newMemoryLegacyProgramNoticeStore()
        let item = CareManagement.newLegacyProgramNotice("code-493", label: "label-671")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
