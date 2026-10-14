import AcmePlatform
import Foundation

extension Consent {
    /// Moves manual language claims through their life cycle and keeps a journal of what it did.
    final class ManualLanguageClaimManager {
        var store: any ManualLanguageClaimStore
        var validator: ManualLanguageClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualLanguageClaimEngine

        init(store: any ManualLanguageClaimStore, validator: ManualLanguageClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualLanguageClaimEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual language claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualLanguageClaimStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual language claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualLanguageClaimStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual language claim \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newManualLanguageClaimManager(_ store: any ManualLanguageClaimStore, clock: any Kit.Clocks.Clock) -> ManualLanguageClaimManager {
        return ManualLanguageClaimManager(
            store: store,
            validator: defaultManualLanguageClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualLanguageClaimEngine()
        )
    }
}
