import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves fallback dispense requests through their life cycle and keeps a journal of what it did.
    final class FallbackDispenseRequestManager {
        var store: any FallbackDispenseRequestStore
        var validator: FallbackDispenseRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackDispenseRequestEngine

        init(store: any FallbackDispenseRequestStore, validator: FallbackDispenseRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackDispenseRequestEngine) {
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
                throw Kit.Failure("fallback dispense request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackDispenseRequestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback dispense request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackDispenseRequestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback dispense request \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newFallbackDispenseRequestManager(_ store: any FallbackDispenseRequestStore, clock: any Kit.Clocks.Clock) -> FallbackDispenseRequestManager {
        return FallbackDispenseRequestManager(
            store: store,
            validator: defaultFallbackDispenseRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackDispenseRequestEngine()
        )
    }
}
