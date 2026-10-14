import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness overrides through their life cycle and keeps a journal of what it did.
    final class WitnessOverrideService {
        var store: any WitnessOverrideStore
        var validator: WitnessOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WitnessOverrideStore, validator: WitnessOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessOverrideStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessOverrideStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newWitnessOverrideService(_ store: any WitnessOverrideStore, clock: any Kit.Clocks.Clock) -> WitnessOverrideService {
        return WitnessOverrideService(
            store: store,
            validator: defaultWitnessOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
