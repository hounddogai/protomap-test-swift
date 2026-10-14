import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure thresholds through their life cycle and keeps a journal of what it did.
    final class DisclosureThresholdCoordinator {
        var store: any DisclosureThresholdStore
        var validator: DisclosureThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureThresholdEngine

        init(store: any DisclosureThresholdStore, validator: DisclosureThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureThresholdEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure threshold \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newDisclosureThresholdCoordinator(_ store: any DisclosureThresholdStore, clock: any Kit.Clocks.Clock) -> DisclosureThresholdCoordinator {
        return DisclosureThresholdCoordinator(
            store: store,
            validator: defaultDisclosureThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureThresholdEngine()
        )
    }
}
