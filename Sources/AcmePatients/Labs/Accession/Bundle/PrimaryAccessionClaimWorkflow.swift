import AcmePlatform
import Foundation

extension Labs {
    /// Moves primary accession claims through their life cycle and keeps a journal of what it did.
    final class PrimaryAccessionClaimWorkflow {
        var store: any PrimaryAccessionClaimStore
        var validator: PrimaryAccessionClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryAccessionClaimEngine

        init(store: any PrimaryAccessionClaimStore, validator: PrimaryAccessionClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryAccessionClaimEngine) {
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
                throw Kit.Failure("primary accession claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAccessionClaimStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary accession claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAccessionClaimStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary accession claim \(code) not found")
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

    static func newPrimaryAccessionClaimWorkflow(_ store: any PrimaryAccessionClaimStore, clock: any Kit.Clocks.Clock) -> PrimaryAccessionClaimWorkflow {
        return PrimaryAccessionClaimWorkflow(
            store: store,
            validator: defaultPrimaryAccessionClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryAccessionClaimEngine()
        )
    }
}
