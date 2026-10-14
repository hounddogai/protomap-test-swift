@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientOutreachTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientOutreachTargetStore = CareManagement.newMemoryLenientOutreachTargetStore()
        let item = CareManagement.newLenientOutreachTarget("code-575", title: "title-12")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
