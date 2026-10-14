import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness entries through their life cycle and keeps a journal of what it did.
    final class WitnessEntryManager {
        var store: any WitnessEntryStore
        var validator: WitnessEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WitnessEntryStore, validator: WitnessEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("witness entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newWitnessEntryManager(_ store: any WitnessEntryStore, clock: any Kit.Clocks.Clock) -> WitnessEntryManager {
        return WitnessEntryManager(
            store: store,
            validator: defaultWitnessEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
