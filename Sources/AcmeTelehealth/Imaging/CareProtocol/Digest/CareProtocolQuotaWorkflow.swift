import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol quotas through their life cycle and keeps a journal of what it did.
    final class CareProtocolQuotaWorkflow {
        var store: any CareProtocolQuotaStore
        var validator: CareProtocolQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolQuotaStore, validator: CareProtocolQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolQuotaStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolQuotaStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newCareProtocolQuotaWorkflow(_ store: any CareProtocolQuotaStore, clock: any Kit.Clocks.Clock) -> CareProtocolQuotaWorkflow {
        return CareProtocolQuotaWorkflow(
            store: store,
            validator: defaultCareProtocolQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
