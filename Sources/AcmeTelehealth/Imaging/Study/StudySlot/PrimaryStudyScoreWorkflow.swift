import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary study scores through their life cycle and keeps a journal of what it did.
    final class PrimaryStudyScoreDesk {
        var store: any PrimaryStudyScoreStore
        var validator: PrimaryStudyScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryStudyScoreEngine

        init(store: any PrimaryStudyScoreStore, validator: PrimaryStudyScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryStudyScoreEngine) {
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
                throw Kit.Failure("primary study score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryStudyScoreStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary study score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryStudyScoreStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary study score \(code) not found")
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

    static func newPrimaryStudyScoreDesk(_ store: any PrimaryStudyScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryStudyScoreDesk {
        return PrimaryStudyScoreDesk(
            store: store,
            validator: defaultPrimaryStudyScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryStudyScoreEngine(flags)
        )
    }
}
