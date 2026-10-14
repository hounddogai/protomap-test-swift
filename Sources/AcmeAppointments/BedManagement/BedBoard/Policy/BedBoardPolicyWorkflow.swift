import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board policies through their life cycle and keeps a journal of what it did.
    final class BedBoardPolicyService {
        var store: any BedBoardPolicyStore
        var validator: BedBoardPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardPolicyEngine

        init(store: any BedBoardPolicyStore, validator: BedBoardPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardPolicyEngine) {
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
                throw Kit.Failure("bed board policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardPolicyStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardPolicyStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board policy \(code) not found")
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

    static func newBedBoardPolicyService(_ store: any BedBoardPolicyStore, clock: any Kit.Clocks.Clock) -> BedBoardPolicyService {
        return BedBoardPolicyService(
            store: store,
            validator: defaultBedBoardPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardPolicyEngine()
        )
    }
}
