import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census bundles through their life cycle and keeps a journal of what it did.
    final class CensusBundleDesk {
        var store: any CensusBundleStore
        var validator: CensusBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CensusBundleStore, validator: CensusBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusBundleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusBundleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newCensusBundleDesk(_ store: any CensusBundleStore, clock: any Kit.Clocks.Clock) -> CensusBundleDesk {
        return CensusBundleDesk(store: store, validator: defaultCensusBundleValidator(), clock: clock, journal: [])
    }
}
