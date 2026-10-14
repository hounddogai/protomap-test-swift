import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential summaries through their life cycle and keeps a journal of what it did.
    final class CredentialSummaryService {
        var store: any CredentialSummaryStore
        var validator: CredentialSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialSummaryEngine

        init(store: any CredentialSummaryStore, validator: CredentialSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialSummaryEngine) {
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
                throw Kit.Failure("credential summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential summary \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newCredentialSummaryService(_ store: any CredentialSummaryStore, clock: any Kit.Clocks.Clock) -> CredentialSummaryService {
        return CredentialSummaryService(
            store: store,
            validator: defaultCredentialSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialSummaryEngine()
        )
    }
}
