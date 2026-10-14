import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves legacy bed board templates through their life cycle and keeps a journal of what it did.
    final class LegacyBedBoardTemplateManager {
        var store: any LegacyBedBoardTemplateStore
        var validator: LegacyBedBoardTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyBedBoardTemplateStore, validator: LegacyBedBoardTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy bed board template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyBedBoardTemplateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy bed board template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyBedBoardTemplateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newLegacyBedBoardTemplateManager(_ store: any LegacyBedBoardTemplateStore, clock: any Kit.Clocks.Clock) -> LegacyBedBoardTemplateManager {
        return LegacyBedBoardTemplateManager(
            store: store,
            validator: defaultLegacyBedBoardTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
