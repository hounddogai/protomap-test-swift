import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form overrides through their life cycle and keeps a journal of what it did.
    final class ConsentFormOverrideService {
        var store: any ConsentFormOverrideStore
        var validator: ConsentFormOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormOverrideEngine

        init(store: any ConsentFormOverrideStore, validator: ConsentFormOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormOverrideEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormOverrideStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormOverrideStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form override \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newConsentFormOverrideService(_ store: any ConsentFormOverrideStore, clock: any Kit.Clocks.Clock) -> ConsentFormOverrideService {
        return ConsentFormOverrideService(
            store: store,
            validator: defaultConsentFormOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormOverrideEngine()
        )
    }
}
