import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census policies through their life cycle and keeps a journal of what it did.
    final class CensusPolicyManager {
        var store: any CensusPolicyStore
        var validator: CensusPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CensusPolicyStore, validator: CensusPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("census policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusPolicyStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusPolicyStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCensusPolicyManager(_ store: any CensusPolicyStore, clock: any Kit.Clocks.Clock) -> CensusPolicyManager {
        return CensusPolicyManager(
            store: store,
            validator: defaultCensusPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
