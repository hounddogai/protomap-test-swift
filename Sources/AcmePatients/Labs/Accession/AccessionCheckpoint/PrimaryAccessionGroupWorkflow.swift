import AcmePlatform
import Foundation

extension Labs {
    /// Moves primary accession groups through their life cycle and keeps a journal of what it did.
    final class PrimaryAccessionGroupService {
        var store: any PrimaryAccessionGroupStore
        var validator: PrimaryAccessionGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryAccessionGroupEngine

        init(store: any PrimaryAccessionGroupStore, validator: PrimaryAccessionGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryAccessionGroupEngine) {
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
                throw Kit.Failure("primary accession group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAccessionGroupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary accession group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAccessionGroupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary accession group \(code) not found")
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

    static func newPrimaryAccessionGroupService(_ store: any PrimaryAccessionGroupStore, clock: any Kit.Clocks.Clock) -> PrimaryAccessionGroupService {
        return PrimaryAccessionGroupService(
            store: store,
            validator: defaultPrimaryAccessionGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryAccessionGroupEngine()
        )
    }
}
