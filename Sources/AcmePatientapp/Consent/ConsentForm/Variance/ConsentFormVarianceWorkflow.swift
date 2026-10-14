import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form variances through their life cycle and keeps a journal of what it did.
    final class ConsentFormVarianceService {
        var store: any ConsentFormVarianceStore
        var validator: ConsentFormVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormVarianceEngine

        init(store: any ConsentFormVarianceStore, validator: ConsentFormVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormVarianceEngine) {
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
                throw Kit.Failure("consent form variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormVarianceStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormVarianceStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form variance \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newConsentFormVarianceService(_ store: any ConsentFormVarianceStore, clock: any Kit.Clocks.Clock) -> ConsentFormVarianceService {
        return ConsentFormVarianceService(
            store: store,
            validator: defaultConsentFormVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormVarianceEngine()
        )
    }
}
