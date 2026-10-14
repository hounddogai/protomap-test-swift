import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves global risk score tiers through their life cycle and keeps a journal of what it did.
    final class GlobalRiskScoreTierManager {
        var store: any GlobalRiskScoreTierStore
        var validator: GlobalRiskScoreTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalRiskScoreTierEngine

        init(store: any GlobalRiskScoreTierStore, validator: GlobalRiskScoreTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalRiskScoreTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global risk score tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalRiskScoreTierStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global risk score tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalRiskScoreTierStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global risk score tier \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newGlobalRiskScoreTierManager(_ store: any GlobalRiskScoreTierStore, clock: any Kit.Clocks.Clock) -> GlobalRiskScoreTierManager {
        return GlobalRiskScoreTierManager(
            store: store,
            validator: defaultGlobalRiskScoreTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalRiskScoreTierEngine()
        )
    }
}
