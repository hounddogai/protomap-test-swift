import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary study digests through their life cycle and keeps a journal of what it did.
    final class PrimaryStudyDigestDesk {
        var store: any PrimaryStudyDigestStore
        var validator: PrimaryStudyDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryStudyDigestEngine

        init(store: any PrimaryStudyDigestStore, validator: PrimaryStudyDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryStudyDigestEngine) {
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
                throw Kit.Failure("primary study digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryStudyDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary study digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryStudyDigestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary study digest \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPrimaryStudyDigestDesk(_ store: any PrimaryStudyDigestStore, clock: any Kit.Clocks.Clock) -> PrimaryStudyDigestDesk {
        return PrimaryStudyDigestDesk(
            store: store,
            validator: defaultPrimaryStudyDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryStudyDigestEngine()
        )
    }
}
