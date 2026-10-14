import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census audits through their life cycle and keeps a journal of what it did.
    final class CensusAuditDesk {
        var store: any CensusAuditStore
        var validator: CensusAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CensusAuditStore, validator: CensusAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusAuditStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusAuditStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newCensusAuditDesk(_ store: any CensusAuditStore, clock: any Kit.Clocks.Clock) -> CensusAuditDesk {
        return CensusAuditDesk(store: store, validator: defaultCensusAuditValidator(), clock: clock, journal: [])
    }
}
