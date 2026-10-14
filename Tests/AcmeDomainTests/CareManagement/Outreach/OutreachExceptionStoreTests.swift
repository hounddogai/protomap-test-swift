@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachExceptionStore = CareManagement.newMemoryOutreachExceptionStore()
        let item = CareManagement.newOutreachException("code-260", title: "title-153")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
